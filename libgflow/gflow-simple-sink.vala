/********************************************************************
# Copyright 2014-2017 Daniel 'grindhold' Brendle, 2015 Daniel Espinosa <esodan@gmail.com>
#
# This file is part of libgtkflow.
#
# libgtkflow is free software: you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later
# version.
#
# libgtkflow is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with libgtkflow.
# If not, see http://www.gnu.org/licenses/.
*********************************************************************/

namespace GFlow {
    /**
     * A simple implementation of {@link GFlow.Sink}.
     */
    public class SimpleSink : Object, Dock, Sink {
        // Dock interface
        protected HashTable<Source, weak GLib.Value?> _val;
        protected GLib.Value? _initial = null;

        private string? _name = null;
        /**
         * This SimpleSink's displayname
         */
        public string? name { 
            get { return this._name; }
            set { this._name = value; }
        }
        public string? _typename = null;
        /**
         * This SimpleSink's typestring
         */
        public string? typename {
            get { return this._typename; }
            set { this._typename = value; }
        }

        /**
         * Defines how many sources can be connected to this sink
         *
         * Setting this variable to a lower value than the current
         * amount of connected sources will have no further effects
         * than not allowing more connections.
         */
        public uint max_sources {get; set; default=1;}

        /**
         * Indicates whether this Sink should be rendered highlighted
         */
        public bool highlight { get; set; default = false; }
        /**
         * Indicates whether this Sink should be rendered active
         */
        public bool active {get; set; default=false;}
        /**
         * A reference to the {@link Node} that this SimpleSink resides in
         */
        public weak Node? node { get; set; }
        /**
         * The value that this SimpleSink was initialized with
         */
        public GLib.Value? initial { get { return _initial; } }

        // Sink Interface
        private List<Source> _sources = new List<Source> ();
        /**
         * The {@link Source}s that this SimpleSink is currently connected to
         */
        public List<Source> sources { get { return _sources; } }

        /**
         * The value that this SimpleSink holds
         */
        public List<weak GLib.Value?> val {
          public owned get {
            var ret = _val.get_values();
            return ret;
          }
          /*set {
            if (!_val.holds (value.type ())) return;
            _val = value;
            this._valid = true;
            // FIXME: This properly is read-only then may let implementators to define how "Change a Value"
          }*/
        }

        /**
         * Connects this SimpleSink to the given {@link Source}. This will
         * only succeed if both {@link Dock}s are of the same type. If this
         * is not the case, an exception will be thrown
         */
        protected void add_source (Source s) throws Error
        {
            if (this.initial.type() != s.initial.type()) {
                throw new NodeError.INCOMPATIBLE_SINKTYPE(
                    "Can't connect. Source has type %s while Sink has type %s".printf(
                        s.val.type().name(), this.initial.type().name()
                    )
                );
            }
            this._sources.append (s);
            s.changed.connect (this.do_source_changed);
            this._val.@set(s, s.val);
        }

        /**
         * Destroys the connection between this SimpleSink and the given {@link Source}
         */
        protected void remove_source (Source s) throws GLib.Error
        {
            if (this._sources.index(s) != -1)
                this._sources.remove(s);
            if (this._val.contains(s))
                this._val.remove(s);
            if (s.is_linked_to(this))
                s.unlink (this);
            this.unlinked(s);
        }
        /**
         * Creates a new SimpleSink with the given initial {@link GLib.Value}
         */
        public SimpleSink (GLib.Value? initial) {
          _val = new HashTable<Source, weak GLib.Value?>(direct_hash, direct_equal);
          _initial = initial;
        }

        /**
         * Returns true if this sink is connected to at least one source
         */
        public bool is_linked() {
            return this.sources.length() > 0;
        }

        /**
         * Returns true if this SimpleSink is connected to the given {@link Dock}
         */
        public bool is_linked_to (Dock dock) { // FIXME Use more logic to know Source type, value or name
            if (!(dock is Source)) return false;
            return this._sources.index((Source) dock) != -1;
        }

        /**
         * Disconnect from the given {@link Dock}
         */
        public new void unlink (Dock dock) throws GLib.Error {
          if (!this.is_linked_to (dock)) return;
          if (dock is Source) {
            this.remove_source((Source) dock);
            this.do_source_changed();
            dock.changed.disconnect (this.do_source_changed);
            changed();
            if (_sources.length () == 0) unlinked (dock);
          }
        }

        private void do_source_changed() {
            foreach (Source s in this._sources) {
                this._val.@set(s, s.val);
            }
            changed ();
        }

        /**
         * Connect to the given {@link Dock}
         */
        public new void link (Dock dock) throws GLib.Error {
            if (this.is_linked_to (dock)) return;
            if (!this.before_linking(this, dock)) return;
            if (this._sources.length()+1 > this.max_sources && this.sources.length() > 0) {
                this.unlink(this.sources.nth_data(this.sources.length()-1));
            }
            if (dock is Source) {
                add_source((Source) dock);
                changed();
                dock.link (this);
                linked (dock);
            }
        }

        /**
         * Disconnect from any {@link Dock} that this SimpleSink is connected to
         */
        public new void unlink_all() throws GLib.Error {
            foreach (Source s in this._sources)
                if (s != null)
                    this.unlink(s);
        }

        /**
         * Retrieve the {@link GLib.Value} that this SimpleSource currently holds.
         */
        public Value? get_value(uint index=0) throws NodeError {
            if (this.val.length() > index)
                return this.val.nth_data(index);
            else
                return null;
        }
    }
}
